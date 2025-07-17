const pool = require('../config/database');

describe('Database Schema Integrity', () => {
  describe('Column Names Match Application Code', () => {
    it('should have correct column names in checkins table', async () => {
      const query = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'checkins' 
        AND table_schema = 'public'
      `;
      
      const result = await pool.query(query);
      const columnNames = result.rows.map(row => row.column_name);
      
      // Should have 'dogs' column, not 'dogs_present'
      expect(columnNames).toContain('dogs');
      expect(columnNames).not.toContain('dogs_present');
      
      // Verify other expected columns
      expect(columnNames).toContain('id');
      expect(columnNames).toContain('user_id');
      expect(columnNames).toContain('dog_park_id');
      expect(columnNames).toContain('checked_in_at');
      expect(columnNames).toContain('checked_out_at');
    });

    it('should have correct column names in friendships table', async () => {
      const query = `
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'friendships' 
        AND table_schema = 'public'
      `;
      
      const result = await pool.query(query);
      const columnNames = result.rows.map(row => row.column_name);
      
      // Should have 'user_id' and 'friend_id', not 'requester_id' and 'addressee_id'
      expect(columnNames).toContain('user_id');
      expect(columnNames).toContain('friend_id');
      expect(columnNames).not.toContain('requester_id');
      expect(columnNames).not.toContain('addressee_id');
      
      // Verify other expected columns
      expect(columnNames).toContain('id');
      expect(columnNames).toContain('status');
      expect(columnNames).toContain('created_at');
      expect(columnNames).toContain('updated_at');
    });
  });

  describe('Required Tables Exist', () => {
    const requiredTables = [
      'users',
      'dogs',
      'dog_parks',
      'friendships',
      'checkins',
      'posts',
      'post_media',
      'post_likes',
      'post_comments',
      'notifications'
    ];

    requiredTables.forEach(tableName => {
      it(`should have ${tableName} table`, async () => {
        const query = `
          SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = $1
          )
        `;
        
        const result = await pool.query(query, [tableName]);
        expect(result.rows[0].exists).toBe(true);
      });
    });
  });

  describe('Critical Indexes Exist', () => {
    it('should have proper indexes on checkins table', async () => {
      const query = `
        SELECT indexname 
        FROM pg_indexes 
        WHERE tablename = 'checkins' 
        AND schemaname = 'public'
      `;
      
      const result = await pool.query(query);
      const indexNames = result.rows.map(row => row.indexname);
      
      // Verify critical indexes exist
      expect(indexNames).toContain('checkins_pkey');
      expect(indexNames.some(name => name.includes('user_id'))).toBe(true);
      expect(indexNames.some(name => name.includes('dog_park_id'))).toBe(true);
    });

    it('should have proper indexes on friendships table', async () => {
      const query = `
        SELECT indexname 
        FROM pg_indexes 
        WHERE tablename = 'friendships' 
        AND schemaname = 'public'
      `;
      
      const result = await pool.query(query);
      const indexNames = result.rows.map(row => row.indexname);
      
      // Verify critical indexes exist
      expect(indexNames).toContain('friendships_pkey');
      expect(indexNames.some(name => name.includes('user_id'))).toBe(true);
      expect(indexNames.some(name => name.includes('friend_id'))).toBe(true);
    });
  });
});