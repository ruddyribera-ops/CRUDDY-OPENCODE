# Supabase — Open-source Firebase Alternative

Full-stack Postgres: auth, realtime, edge functions, storage.

## Quick Reference

| Feature | Supabase Equivalent |
|---------|---------------------|
| Database | PostgreSQL (direct, not ORM) |
| Auth | `@supabase/supabase-js` — email, OAuth, magic links |
| Realtime | `supabase.channel()` — PostgreSQL change listeners |
| Storage | `supabase.storage` — S3-compatible file storage |
| Edge Functions | Deno runtime, deployed globally |

## Auth Patterns

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
)

// Sign up with email
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'securepassword',
  options: {
    data: { role: 'customer' } // custom metadata
  }
})

// Sign in
const { data: { user } } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'securepassword'
})

// OAuth (Google)
const { data: { url } } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: { redirectTo: 'https://myapp.com/callback' }
})
```

## Row Level Security (RLS)

**Critical:** Supabase defaults to no RLS — enable it explicitly.

```sql
-- Users can only read their own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
USING (auth.uid() = user_id);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = user_id);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
```

## Realtime Subscriptions

```javascript
// Listen for new orders
const channel = supabase
  .channel('orders')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'orders' },
    (payload) => handleNewOrder(payload.new)
  )
  .subscribe()

// Unsubscribe when done
channel.unsubscribe()
```

## Edge Functions

```typescript
// supabase/functions/process-payment/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  const { order_id, amount } = await req.json()
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  // Process payment (stub)
  const payment = await processStripePayment(amount)
  
  await supabase.from('orders').update({
    status: 'paid',
    paid_at: new Date().toISOString()
  }).eq('id', order_id)
  
  return new Response(JSON.stringify({ success: true }))
})
```

## Storage

```javascript
// Upload file
const { data, error } = await supabase.storage
  .from('avatars')
  .upload(`${user_id}/profile.jpg`, fileBuffer, {
    contentType: 'image/jpeg',
    upsert: true
  })

// Get public URL
const { data: { publicUrl } } = supabase.storage
  .from('avatars')
  .getPublicUrl(`${user_id}/profile.jpg`)
```

## Database Connection (Direct Postgres)

```python
# Python — direct connection for heavy queries
import psycopg2

conn = psycopg2.connect(
    host="db.xxx.supabase.co",
    port=5432,
    database="postgres",
    user="postgres",
    password=os.environ['SUPABASE_DB_PASSWORD'],
    sslmode='require'
)
```

## Integration with OpenCode Skills

- Use `auth-patterns` for auth flow best practices
- Use `database-patterns` for PostgreSQL-specific patterns
- Use `fullstack-dev` for backend service patterns

## Resources

- [awesome-supabase](https://github.com/lyqht/awesome-supabase)
- [supabase.com/docs](https://supabase.com/docs)