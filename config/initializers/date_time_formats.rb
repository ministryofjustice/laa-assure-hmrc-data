# These can be used in views as below
#
# %= @user.last_signed_in_at.to_s(:default) %>
# %= @user.last_signed_in_at.to_s(:date_only) %>
#
Date::DATE_FORMATS[:default] = "%d %b %Y" # 01 Jan 2023

Time::DATE_FORMATS[:default] = "%d %b %Y %k:%M"
Time::DATE_FORMATS[:date_only] = "%d %b %Y"
