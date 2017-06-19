class AddBankAccountIdToPerson < ActiveRecord::Migration
  def change
    add_column :people, :bank_account_id, :string
  end
end
