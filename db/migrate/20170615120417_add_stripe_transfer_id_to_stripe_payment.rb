class AddStripeTransferIdToStripePayment < ActiveRecord::Migration
  def change
    add_column :stripe_payments, :stripe_transfer_id, :string
  end
end
