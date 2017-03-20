class Favourite < ApplicationRecord
  belongs_to :linked, polymorphic: true, touch: true
  belongs_to :user, touch: true

  Seyu = 'seyu'
  Mangaka = 'mangaka'
  Producer = 'producer'
  Person = 'person'

  EntriesPerCharacter = 18
  EntriesPerAnime = 7
  EntriesPerManga = 7
  EntriesPerPerson = 9
end
