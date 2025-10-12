FactoryBot.define do
  factory :game do
    traits_for_enum :kind, %i[loaded_questions]
    loaded_questions

    slug { ::SecureRandom.alphanumeric(6) }
    document { {}.to_json }
  end
end
