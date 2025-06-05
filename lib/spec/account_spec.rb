require_relative './spec_helper'
require_relative '../models/account'

RSpec.describe Account do
  let(:account) do
    Account.new(
      id: 'acc123',
      name: 'Test Account',
      currency: '$',
      balance: 1000.0,
      nature: 'Savings'
    )
  end

  describe '#initialize' do
    it 'sets correct attributes' do
      expect(account.id).to eq('acc123')
      expect(account.balance).to eq(1000.0)
    end
  end

  describe '#add_transaction' do
    it 'adds transaction to account' do
      expect {
        account.add_transaction(double('Transaction'))
      }.to change { account.transactions.size }.by(1)
    end
  end

  describe '#to_hash' do
    it 'returns correct hash representation' do
      expect(account.to_hash).to include(
        name: 'Test Account',
        balance: 1000.0
      )
    end
  end
end