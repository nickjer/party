# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  signature 'sig'

  configure_code_diagnostics(D::Ruby.all_error)

  implicitly_returns_nil!
end
