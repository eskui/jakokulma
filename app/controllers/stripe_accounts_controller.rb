class StripeAccountsController < ApplicationController
  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_your_settings")
  end

  before_filter :ensure_stripe_enabled
  
  def index
    @selected_left_navi_link = "payments"

    community_ready_for_payments = @current_community.stripe_in_use?
    unless community_ready_for_payments
      flash.now[:warning] = t("stripe_accounts.admin_account_not_connected",
                            contact_admin_link: view_context.link_to(
                              t("stripe_accounts.contact_admin_link_text"),
                                new_user_feedback_path)).html_safe
    end
    
    community_currency = @current_community.currency
    community_country_code = LocalizationUtils.valid_country_code(@current_community.country)
    
    Stripe.api_key = @current_community.payment_gateway.stripe_secret_key
    Stripe.api_version = '2015-04-07'
    create_managed_account_if_not_exists()
    render(locals: {
      community_ready_for_payments: community_ready_for_payments,
      left_hand_navigation_links: settings_links_for(@current_user, @current_community),
      currency: community_currency,
    })
  end

  def oauth
    connector = StripeOauth.new( @current_user, @current_community )
    url, error = connector.oauth_url( redirect_uri: stripe_confirm_url(locale: nil) )
    if url.nil?
      flash[:error] = error
      redirect_to stripe_account_settings_payment_path( @current_user )
    else
      redirect_to url
    end
  end

  def edit_bank_details
    @selected_left_navi_link = "payments"
    Stripe.api_key = @current_community.payment_gateway.stripe_secret_key
    render(locals: {
      left_hand_navigation_links: settings_links_for(@current_user, @current_community),
    })
    
  end
  
  private

  # Before filter
  def ensure_stripe_enabled
    unless StripeHelper.stripe_active?(@current_community.id)
      flash[:error] = t("stripe_accounts.new.stripe_not_enabled")
      redirect_to person_settings_path(@current_user)
    end
  end

  def create_managed_account_if_not_exists
    unless @current_user.stripe_account_connected?
      create_managed_account
    end
  end

  def create_managed_account
    Stripe.api_key = @current_community.payment_gateway.stripe_secret_key
    connector = StripeManaged.new( @current_user)
    account, error = connector.create_account!(@current_community.country, true, request.remote_ip)
      
    unless account
      flash[:error] = error || "Unable to create Stripe account!"
      return redirect_to root_url
    end
  end

  def create_oauth_account_if_not_exists
    unless @current_user.stripe_account_connected?
      create_oauth_account
    end
  end

  def create_oauth_account
    Stripe.api_key = @current_community.payment_gateway.stripe_secret_key
    connector = StripeOauth.new( @current_user)
    url, error = connector.oauth_url( redirect_uri: 'https://bestill.nabomat.no/connect/confirm' )

    if url.nil?
      flash[:error] = error || "Unable to connect Stripe account!"
      return redirect_to root_url
    else
      # redirect_to url
    end
  end

  # Confirm a connection to a Stripe account.
  # Only works on the currently logged in user.
  # See app/services/stripe_connect.rb for #verify! details.
  def confirm
    connector = StripeOauth.new( current_user )
    if params[:code]
      # If we got a 'code' parameter. Then the
      # connection was completed by the user.
      connector.verify!( params[:code] )

    elsif params[:error]
      # If we have an 'error' parameter, it's because the
      # user denied the connection request. Other errors
      # are handled at #oauth_url generation time.
      flash[:error] = "Authorization request denied."
    end

    redirect_to root_url
  end

end
