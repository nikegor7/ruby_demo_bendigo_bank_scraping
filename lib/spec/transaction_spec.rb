require_relative './spec_helper'
require_relative '../models/transaction'

RSpec.describe Transaction do
  let(:transaction) do
    Transaction.new(
      date: '2023-01-01',
      description: 'Test',
      amount: 100,
      currency: '$',
      account_name: 'Test Account'
    )
  end

  describe '#initialize' do
    it 'sets correct attributes' do
      expect(transaction.date).to eq('2023-01-01')
      expect(transaction.amount).to eq(100)
    end
  end

  describe '#to_hash' do
    it 'returns correct hash representation' do
      expect(transaction.to_hash).to include(
        description: 'Test',
        amount: 100
      )
    end
  end
end