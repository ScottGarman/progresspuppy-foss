require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  def setup
    @user = User.new(first_name: 'Bubba',
                     last_name: 'Jones',
                     email: 'bubbajones@example.com',
                     password: 'foobarbaz123',
                     password_confirmation: 'foobarbaz123',
                     accepted_tos: true)
    @user.save!

    @setting = Setting.new
  end

  test 'setting must be associated with a User' do
    assert @setting.invalid?
    assert @setting.errors[:user_id].any?

    @user.setting = @setting
    assert @setting.valid?
  end
end
