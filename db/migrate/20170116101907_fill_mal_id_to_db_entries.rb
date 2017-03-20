class FillMalIdToDbEntries < ActiveRecord::Migration
  def change
    ApplicationRecord.connection.execute('update animes set mal_id = id')
    ApplicationRecord.connection.execute('update mangas set mal_id = id')
    ApplicationRecord.connection.execute('update characters set mal_id = id')
    ApplicationRecord.connection.execute('update people set mal_id = id')
  end
end
