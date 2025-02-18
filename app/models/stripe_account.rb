# == Schema Information
#
# Table name: stripe_accounts
#
#  id                    :integer          not null, primary key
#  person_id             :string(255)
#  publishable_key       :string(255)
#  secret_key            :string(255)
#  stripe_user_id        :string(255)
#  currency              :string(255)
#  stripe_account_type   :string(255)
#  stripe_account_status :text(65535)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class StripeAccount < ActiveRecord::Base
  serialize :stripe_account_status, JSON

  belongs_to :person

  # Stripe account type checks
  def managed?; stripe_account_type == 'managed'; end

  def stripe_manager
    StripeManaged.new(self.person)
  end

  def tranfers_enabled?
    stripe_account_status["charges_enabled"] == true && stripe_account_status["transfers_enabled"] == true
  end
end
