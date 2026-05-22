# PHP Backend — Laravel & Symfony

Enterprise-grade PHP frameworks for modern backend development.

## Laravel (Elegant, Full-Stack)

### Project Structure

```
backend/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── UserController.php
│   │   └── Middleware/
│   │       └── Authenticate.php
│   ├── Models/
│   │   └── User.php
│   ├── Services/
│   │   └── UserService.php
│   └── Exceptions/
├── database/
│   ├── migrations/
│   └── seeders/
├── routes/
│   └── api.php
├── config/
├── tests/
└── composer.json
```

### Laravel API Setup

```bash
# Create new Laravel API project
composer create-project laravel/laravel backend
cd backend
php artisan install:api

# Generate controller
php artisan make:controller Api/UserController --api

# Generate model + migration
php artisan make:model User -m

# Run migrations
php artisan migrate
```

### Eloquent Models

```php
// app/Models/User.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    protected $fillable = ['name', 'email', 'password'];
    protected $hidden = ['password', 'remember_token'];
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_admin' => 'boolean',
    ];

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
```

### Controllers

```php
// app/Http/Controllers/Api/UserController.php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    public function index(): JsonResponse
    {
        $users = User::paginate(20);
        return response()->json($users);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
        ]);

        $user = User::create([
            ...$data,
            'password' => Hash::make($data['password']),
        ]);

        return response()->json($user, 201);
    }

    public function show(int $id): JsonResponse
    {
        $user = User::findOrFail($id);
        return response()->json($user);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $data = $request->validate([
            'name' => 'sometimes|string|max:100',
            'email' => 'sometimes|email|unique:users,email,' . $id,
        ]);
        $user->update($data);
        return response()->json($user);
    }

    public function destroy(int $id): JsonResponse
    {
        User::destroy($id);
        return response()->json(null, 204);
    }
}
```

### API Routes

```php
// routes/api.php
use App\Http\Controllers\Api\UserController;

Route::apiResource('users', UserController::class);

// Or explicit
Route::prefix('v1')->group(function () {
    Route::apiResource('users', UserController::class);
    Route::post('users/{id}/orders', [OrderController::class, 'store']);
});
```

### Authentication (Sanctum)

```bash
composer require laravel/sanctum
php artisan install:api
```

```php
// SPA login (Sanctum)
Route::post('/login', function (Request $request) {
    $request->validate([
        'email' => 'required|email',
        'password' => 'required',
    ]);

    if (!Auth::attempt($request->only('email', 'password'))) {
        throw ValidationException::withMessages([
            'email' => ['Invalid credentials'],
        ]);
    }

    $user = User::where('email', $request->email)->first();
    $token = $user->createToken('api-token')->plainTextToken;

    return response()->json(['token' => $token]);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', fn() => auth()->user());
    Route::post('/logout', fn() => auth()->user()->currentAccessToken()->delete());
});
```

### Laravel Service Pattern

```php
// app/Services/UserService.php
namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserService
{
    public function createUser(array $data): User
    {
        return User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
        ]);
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }
}
```

## Symfony (Enterprise, Component-Based)

### Basic Setup

```bash
composer create-project symfony/skeleton backend
cd backend
composer require api
composer require doctrine
php -S 127.0.0.1:8000 -t public/
```

### Doctrine Entities

```php
// src/Entity/User.php
namespace App\Entity;

use App\Repository\UserRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
class User
{
    #[ORM\Id, ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 100)]
    private string $name;

    #[ORM\Column(type: 'string', unique: true)]
    private string $email;

    public function getId(): ?int { return $this->id; }
    public function getName(): string { return $this->name; }
    public function setName(string $name): self { $this->name = $name; return $this; }
}
```

### Symfony Controller

```php
// src/Controller/UserController.php
namespace App\Controller;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;

class UserController extends AbstractController
{
    #[Route('/api/users', methods: ['GET'])]
    public function index(EntityManagerInterface $em): JsonResponse
    {
        $users = $em->getRepository(User::class)->findAll();
        return $this->json($users);
    }

    #[Route('/api/users', methods: ['POST'])]
    public function create(Request $request, EntityManagerInterface $em): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        $user = new User();
        $user->setName($data['name']);
        $user->setEmail($data['email']);
        $em->persist($user);
        $em->flush();
        return $this->json($user, 201);
    }
}
```

## Deployment

```dockerfile
# Laravel
FROM php:8.2-fpm-alpine
RUN docker-php-ext-install pdo pdo_mysql
COPY . /var/www/html
RUN composer install --no-dev --optimize-autoloader
EXPOSE 9000
CMD ["php-fpm"]
```

## Laravel vs Symfony

| Aspect | Laravel | Symfony |
|--------|---------|---------|
| Complexity | Lower | Higher |
| Flexibility |Opinionated | Modular |
| Ecosystem | Composer + Laravel Spark | Composer only |
| Best for | Fast development | Enterprise, long-lived |
| Learning curve | Gentle | Steep |

## Resources

- [awesome-laravel](https://github.com/chiraggude/awesome-laravel)
- [awesome-symfony](https://github.com/sitepoint-editors/awesome-symfony)