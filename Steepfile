# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  signature "sig"

  check "app/channels"
  check "app/games"
  check "app/lib"

  library "json"
  library "yaml"

  configure_code_diagnostics(D::Ruby.all_error)

  implicitly_returns_nil!
end
