# == Schema Information
#
# Table name: stripe_payments
#
#  id                    :integer          not null, primary key
#  payer_id              :string(255)
#  recipient_id          :string(255)
#  organization_id       :string(255)
#  transaction_id        :integer
#  status                :string(255)
#  community_id          :integer
#  sum_cents             :integer
#  currency              :string(255)
#  stripe_transaction_id :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  stripe_transfer_id    :string(255)
#

class StripePayment < ActiveRecord::Base
  include MathHelper

  belongs_to :tx, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :community
  belongs_to :payer, foreign_key: :payer_id, class_name: 'Person'
  belongs_to :recipient, foreign_key: :recipient_id, class_name: 'Person'

  monetize :sum_cents, allow_nil: true, with_model_currency: :currency

  delegate :commission_from_seller, to: :community

  def sum_exists?
    !sum_cents.nil?
  end

  def total_sum
    sum
  end

  # Build default payment sum by listing
  # Note: Consider removing this :(
  def default_sum(listing, vat=0)
    self.sum = listing.price
  end

  def validate_sum
    unless sum_exists?
      errors.add(:base, "Payment is not valid without sum")
    end
  end

  def paid!
    update_attribute(:status, "paid")
  end

  def disbursed!
    update_attribute(:status, "disbursed")
    # Notification here?
  end

  def total_commission_percentage
    Maybe(commission_from_seller).or_else(0).to_f / 100.to_f
  end

  def total_commission
    total = total_sum * total_commission_percentage
    ps = PaymentSettings.last
    minimum_transaction_fee = ps.minimum_transaction_fee
    if total.to_f < minimum_transaction_fee.to_f
      return minimum_transaction_fee
    else
      return total
    end
  end

  def seller_gets
    total_sum - total_commission
  end

  def total_commission_without_vat
    vat = Maybe(community).vat.or_else(0).to_f / 100.to_f
    total_commission / (1 + vat)
  end

  def payment_gateway
    community.payment_gateway
  end
end
