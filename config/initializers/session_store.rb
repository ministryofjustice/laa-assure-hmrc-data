# set secure: true
Rails.application.config.session_store :cookie_store, key: "_laa_assure_hmrc_data_session", secure: Rails.env.production?
