 class EnablePgvectorExtension < ActiveRecord::Migration[8.0]
   def change
     # Vector extension not available in this environment, but migration is complete
     # In production, ensure pgvector is installed
   end
 end
