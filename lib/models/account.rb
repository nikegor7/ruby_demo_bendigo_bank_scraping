class Account
  attr_accessor :id, :name, :currency, :balance, :nature, :transactions

  def initialize(id:, name:, currency:, balance:, nature:, transactions: [])
    @id = id
    @name = name
    @currency = currency
    @balance = balance
    @nature = nature
    @transactions = []
  end

  def add_transaction(transaction)
    @transactions << transaction
  end

  def to_hash
    {
      id: @id,
      name: @name,
      currency: @currency,
      balance: @balance,
      nature: @nature,
      transactions: @transactions.map(&:to_hash)
    }
  end
end