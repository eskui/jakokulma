class StripeManaged < Struct.new( :user )
  ALLOWED = [ 'US', 'CA', 'NO', 'SE', 'FI' ] # public beta
  COUNTRIES = [
    { name: 'Sweden', code: 'SE' },
    { name: 'United States', code: 'US' },
    { name: 'Canada', code: 'CA' },
    { name: 'Australia', code: 'AU' },
    { name: 'United Kingdom', code: 'GB' },
    { name: 'Ireland', code: 'IE' },
    { name: 'Finland', code: 'FI' }
  ]

  def create_account!( country, tos_accepted, ip )
    return nil unless tos_accepted
    return nil unless country.in?( COUNTRIES.map { |c| c[:code] } )

    begin
      @account = Stripe::Account.create(
        managed: true,
        country: country,
        tos_acceptance: {
          ip: ip,
          date: Time.now.to_i
        },
        legal_entity: {
          type: 'individual',
        }
      )
    rescue Exception => e
      @account = nil
      @error = e.message # TODO: improve
    end

    if @account
      gateway                         =   user.stripe_account || user.build_stripe_account
      gateway.currency                =   @account.default_currency
      gateway.stripe_account_type     =   'managed'
      gateway.stripe_user_id          =   @account.id
      gateway.secret_key              =   @account.keys.secret
      gateway.publishable_key         =   @account.keys.publishable
      gateway.stripe_account_status   =   account_status
      gateway.save!
    end

    return @account, @error
  end

  def upload_identity(file: , account_id: )
    # Stripe.api_key = PLATFORM_SECRET_KEY
    Stripe::FileUpload.create(
      {
        :purpose => 'identity_document',
        # :file => File.new('/path/to/a/file.jpg')
        :file => file
      },
      {:stripe_account => account_id}
    )
  end

  def update_account!( params: nil, document: nil )
    if document.present?
      upload_result = upload_identity(file: document, account_id: account.id)
      account.legal_entity.verification.document = upload_result.id
      account.save
    end

    if params
      if params[:bank_account_token].present?
        account.external_account = params[:bank_account_token]
        account.save
      end

      if params[:legal_entity].present?
        # clean up dob fields
        params[:legal_entity][:dob] = {
          year: params[:legal_entity].delete('dob(1i)'),
          month: params[:legal_entity].delete('dob(2i)'),
          day: params[:legal_entity].delete('dob(3i)')
        }

        # update legal_entity hash from the params
        params[:legal_entity].entries.each do |key, value|
          if [ :address, :dob ].include? key.to_sym
            value.entries.each do |akey, avalue|
              next if avalue.blank?
              # Rails.logger.error "#{akey} - #{avalue.inspect}"
              account.legal_entity[key] ||= {}
              account.legal_entity[key][akey] = avalue
            end
          else
            next if value.blank?
            # Rails.logger.error "#{key} - #{value.inspect}"
            account.legal_entity[key] = value
          end
        end

        # copy 'address' as 'personal_address'
        pa = account.legal_entity['address'].dup.to_h
        account.legal_entity['personal_address'] = pa

        account.save
      end
    end

    user.stripe_account.update_attributes(
      stripe_account_status: account_status
    )
  end

  def legal_entity
    account.legal_entity
  end

  def needs?( field )
    user.stripe_account.stripe_account_status['fields_needed'].grep( Regexp.new( /#{field}/i ) ).any?
  end

  def bank_details
    account.external_accounts.data.collect{|acc| acc if acc.default_for_currency == true}.first
  end

  def supported_bank_account_countries
    country_codes = case account.country
                    when 'NO' then %w{ NO }
                    when 'US' then %w{ US }
                    when 'CA' then %w{ US CA }
                    when 'IE', 'UK' then %w{ IE UK US }
                    when 'AU' then %w{ AU }
                    end
    COUNTRIES.select do |country|
      country[:code].in? country_codes
    end
  end

  def visible_account_no
    "*******" + account.external_accounts.data.collect{|acc| acc.last4 if acc.default_for_currency == true}.first
  end

  protected

  def account_status
    {
      details_submitted: account.details_submitted,
      charges_enabled: account.charges_enabled,
      transfers_enabled: account.transfers_enabled,
      fields_needed: account.verification.fields_needed,
      due_by: account.verification.due_by
    }
  end


  def account
    @account ||= Stripe::Account.retrieve( user.stripe_account.stripe_user_id )
  end

end