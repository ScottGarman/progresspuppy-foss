class SettingsController < ApplicationController
  before_action :logged_in_user

  def edit
  end

  def toggle_display_quotes
    @display_quotes = current_user.setting.display_quotes
    current_user.setting.display_quotes = !@display_quotes
    current_user.setting.save!
    @display_quotes = current_user.setting.display_quotes

    respond_to do |f|
      f.js
    end
  end
end
