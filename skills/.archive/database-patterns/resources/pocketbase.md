# PocketBase — Go Backend in One File

Open-source, Go-based backend with embedded SQLite, auth, file storage, REST API.

## Quick Reference

| Feature | Description |
|---------|-------------|
| **Single binary** | Embeds SQLite + Go HTTP server |
| **Built-in auth** | Email/password, OAuth, MFA support |
| **File storage** | Local or S3-compatible |
| **Realtime** | Server-Sent Events for live updates |
| **Admin UI** | Built-in dashboard at `/ _/ ` |

## Auth Patterns

```go
// Create auth record
func RegisterUser(ctx echo.Context) error {
    e := echo.New()
    body := map[string]interface{}{}
    e.Bind(ctx, &body)
    
    // PocketBase handles password hashing automatically
    record, err := app.FindAuthRecordByEmail("users", body["email"].(string))
    if err != nil {
        // Create new user
        record, err = app.Database.CreateRecord("users", map[string]interface{}{
            "email":    body["email"],
            "password": body["password"],
        })
    }
    return record, err
}
```

## API Examples (curl)

```bash
# Register
curl -X POST http://localhost:8090/api/collections/users/records \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"securepassword"}'

# Login (returns auth token)
curl -X POST http://localhost:8090/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"user@example.com","password":"securepassword"}'

# Authenticated request
curl http://localhost:8090/api/collections/users/records \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## SSE Realtime

```javascript
// Client-side realtime subscription
const eventSource = new EventSource(
  'http://localhost:8090/api/collections/tasks/records?subscribe=*'
)

eventSource.onmessage = (event) => {
  const task = JSON.parse(event.data)
  console.log('New task:', task)
}

// React hook pattern
function usePocketBaseRealtime(table) {
  const [records, setRecords] = useState([])
  
  useEffect(() => {
    const sub = pb.collection(table).subscribe('*', (e) => {
      if (e.action === 'create') setRecords(r => [...r, e.record])
      if (e.action === 'update') setRecords(r => r.map(x => x.id === e.record.id ? e.record : x))
      if (e.action === 'delete') setRecords(r => r.filter(x => x.id !== e.record.id))
    })
    return () => pb.collection(table).unsubscribe(sub)
  }, [table])
  
  return records
}
```

## File Upload

```javascript
// Upload form data
const formData = new FormData()
formData.append('file', fileInput.files[0])
formData.append('name', 'My Document')

const record = await pb.collection('documents').create(formData)

// Download
const url = pb.files.getURL(record, record.file, { thumb: '100x100' })
```

## Go SDK

```go
import "github.com/pocketbase/pocketbase"

func main() {
    app := pocketbase.New()
    
    // Register hooks
    app.OnRecordCreateRequest("tasks").Add(func(e *core.RecordCreateEvent) error {
        e.Record.Set("status", "pending")
        return nil
    })
    
    app.Start()
}
```

## Deployment Patterns

```dockerfile
# Dockerfile
FROM golang:1.21-alpine
WORKDIR /app
COPY pb .
RUN chmod +x pb
EXPOSE 8090
CMD ["./pb", "serve", "--http=0.0.0.0:8090"]
```

**Railway deployment:**
- Upload the binary + `./pb` directory
- Set `DATADIR` env var to persistent volume
- Use `/ _/` admin panel to configure

## Comparison with Supabase

| Feature | PocketBase | Supabase |
|---------|------------|----------|
| Language | Go | PostgreSQL + Node.js |
| Database | Embedded SQLite | External PostgreSQL |
| Scalability | Single instance | Horizontal scale |
| Admin UI | Built-in | Built-in |
| Best for | Simple apps, side projects | Production scale |

## Resources

- [awesome-pocketbase](https://github.com/benallfree/awesome-pocketbase)
- [pocketbase.io/docs](https://pocketbase.io/docs/)