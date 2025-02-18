# == Schema Information
#
# Table name: payment_settings
#
#  id                               :integer          not null, primary key
#  active                           :boolean          not null
#  community_id                     :integer          not null
#  payment_gateway                  :string(64)
#  payment_process                  :string(64)
#  commission_from_seller           :integer
#  minimum_price_cents              :integer
#  minimum_price_currency           :string(3)
#  minimum_transaction_fee_cents    :integer
#  minimum_transaction_fee_currency :string(3)
#  confirmation_after_days          :integer          not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#
# Indexes
#
#  index_payment_settings_on_community_id  (community_id)
#

class PaymentSettings < ActiveRecord::Base

  attr_accessible(
    :active,
    :community_id,
    :payment_gateway,
    :payment_process,
    :commission_from_seller,
    :minimum_price_cents,
    :minimum_price_currency,
    :minimum_transaction_fee_cents,
    :minimum_transaction_fee_currency,
    :confirmation_after_days)

  validates_presence_of(:community_id)

  monetize :minimum_transaction_fee_cents, allow_nil: true, with_model_currency: :minimum_price_currency
end
