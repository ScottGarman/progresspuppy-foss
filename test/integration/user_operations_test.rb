require 'test_helper'

class UserOperationsTest < ActionDispatch::IntegrationTest
  test 'Update user profile information' do
    donpdonp = users(:donpdonp)
    log_in_as(donpdonp)

    # View user profile
    get user_profile_path
    assert_response :success
    assert_template 'users/edit'

    # Edit first name (blank name)
    patch user_path(donpdonp), params: { user: { first_name: '' } }
    assert_select 'p#first_name_error_msg', /can't be blank/
    donpdonp.reload
    assert_equal donpdonp.first_name, 'Don'

    # Edit first name (name too long)
    patch user_path(donpdonp), params: { user: { first_name: 'a' * 51 } }
    assert_select 'p#first_name_error_msg', /is too long/
    donpdonp.reload
    assert_equal donpdonp.first_name, 'Don'

    # Edit first name (valid)
    patch user_path(donpdonp), params: { user: { first_name: 'NotDon' } }
    assert_redirected_to user_profile_path
    donpdonp.reload
    assert_equal donpdonp.first_name, 'NotDon'

    # Edit last name
    patch user_path(donpdonp), params: { user: { last_name: 'NotDonLN' } }
    assert_redirected_to user_profile_path
    donpdonp.reload
    assert_equal donpdonp.last_name, 'NotDonLN'

    # Edit email
    patch user_path(donpdonp), params: { user:
      { email: 'notdonpdonp@example.com' } }
    assert_redirected_to user_profile_path
    donpdonp.reload
    assert_equal donpdonp.email, 'notdonpdonp@example.com'

    # Change password
    patch user_path(donpdonp), params: { user:
      { password: 'foobarbaz123', password_confirmation: 'foobarbaz123' } }
    assert_redirected_to user_profile_path
    donpdonp.reload
    # TODO: Guessing I need to log out and log back in to test this properly?

    # Change time zone
    patch user_path(donpdonp), params: { user:
      { time_zone: 'Eastern Time (US & Canada)' } }
    assert_redirected_to user_profile_path
    donpdonp.reload
    assert_equal donpdonp.time_zone, 'Eastern Time (US & Canada)'
  end

  test 'ensure users cannot delete other users' do
    donpdonp = users(:donpdonp)
    ows = users(:onewheelskyward)

    # donpdonp logs in an verifies his user profile information
    log_in_as(donpdonp)

    get user_profile_path
    assert_response :success
    assert_template 'users/edit'

    assert_equal donpdonp.first_name, 'Don'
    assert_equal donpdonp.last_name, 'DonLN'
    assert_equal donpdonp.email, 'donpdonp@example.com'

    # onewheelskyward logs in and tries to delete donpdonp's user account
    log_in_as(ows)
    delete user_path(donpdonp)
    assert_redirected_to root_path

    donpdonp.reload
    assert_equal donpdonp.first_name, 'Don'
  end

  test 'ensure an admin user can delete users' do
    leofsiege = users(:leofsiege)
    donpdonp = users(:donpdonp)

    assert leofsiege.admin
    assert_not donpdonp.admin

    log_in_as(leofsiege)
    delete user_path(donpdonp)
    assert_redirected_to users_path

    assert_raises 'ActiveRecord::RecordNotFound' do
      donpdonp.reload
    end
  end
end
