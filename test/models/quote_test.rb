require 'test_helper'

class QuoteTest < ActiveSupport::TestCase
  def setup
    @user = User.new(first_name: 'Bubba',
                     last_name: 'Jones',
                     email: 'bubbajones@example.com',
                     password: 'foobarbaz123',
                     password_confirmation: 'foobarbaz123',
                     accepted_tos: true)
    @user.save!

    @quote = Quote.new(quotation: 'Sample Quotation', source: 'Source')
  end

  test 'should be valid' do
    @user.quotes << @quote
    assert @quote.valid?
  end

  test 'quotation must be associated with a User' do
    assert @quote.invalid?
    assert @quote.errors[:user_id].any?
  end

  test 'quotation should be present and not empty' do
    @quote.quotation = '  '
    assert @quote.invalid?
    assert @quote.errors[:quotation].any?
  end

  test 'source should be present and not empty' do
    @quote.source = '  '
    assert @quote.invalid?
    assert @quote.errors[:source].any?
  end

  test 'quotation should not be too long' do
    @user.quotes << @quote
    @quote.quotation = 'a' * 256
    assert @quote.invalid?
    assert @quote.errors[:quotation].any?

    @quote.quotation = 'a' * 255
    assert @quote.valid?
  end

  test 'source should not be too long' do
    @user.quotes << @quote
    @quote.source = 'a' * 256
    assert @quote.invalid?
    assert @quote.errors[:source].any?

    @quote.source = 'a' * 255
    assert @quote.valid?
  end
end
