# Build Tools — Sass, Less, PostCSS, Browserify

CSS preprocessors and build tools for modern frontend development.

## Sass (Syntactically Awesome Style Sheets)

### Setup

```bash
npm install -D sass
```

```javascript
// vite.config.js (Vite handles Sass automatically)
import { defineConfig } from 'vite'
export default defineConfig({
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "src/styles/_variables.scss";`
      }
    }
  }
})
```

### Variables & Mixins

```scss
// _variables.scss
$primary: #0ea5e9;
$radius: 0.5rem;

@mixin card($bg: white) {
  background: $bg;
  border-radius: $radius;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

// usage
.card {
  @include card;
  padding: 1rem;

  &-header {
    border-bottom: 1px solid #eee;
    margin: -1rem -1rem 1rem;
    padding: 1rem;
  }
}
```

### Nesting

```scss
.nav {
  display: flex;
  gap: 1rem;

  &__item {
    position: relative;

    &:hover .nav__dropdown {
      display: block;
    }
  }

  &__dropdown {
    display: none;
    position: absolute;
    top: 100%;
    left: 0;
  }

  // Pseudo-elements
  &::before {
    content: '';
    position: absolute;
  }
}
```

### Functions & Operations

```scss
// Color functions
$base: #0ea5e9;
lighten($base, 10%);
darken($base, 10%);
adjust-hue($base, 20deg);

// Math
.container {
  width: 100% / 3 - $gutter;
}
```

## Less

```less
// variables
@primary: #0ea5e9;
@radius: 0.5rem;

// mixins
.card(@bg: white) {
  background: @bg;
  border-radius: @radius;
}

// nesting
.nav {
  display: flex;
  &__item { padding: 0.5rem; }
}
```

## PostCSS

### Setup

```bash
npm install -D postcss postcss-cli autoprefixer
```

```javascript
// postcss.config.js
module.exports = {
  plugins: [
    require('autoprefixer'), // Add vendor prefixes
    require('cssnano'),      // Minify CSS
  ]
}
```

```json
// package.json scripts
{
  "css:build": "postcss src/styles.css -o dist/styles.css",
  "css:watch": "postcss src/styles.css -o dist/styles.css --watch"
}
```

### CSS Custom Properties + PostCSS

```css
/* Use CSS variables, PostCSS handles fallbacks */
:root {
  --primary: #0ea5e9;
}

.button {
  background: var(--primary);
  /* PostCSS generates: */
  /* background: #0ea5e9; */
}
```

## Browserify (Module Bundler)

### Setup

```bash
npm install -D browserify watchify
npm install -D babelify @babel/core @babel/preset-env
```

### Bundling

```bash
# Basic
browserify src/main.js -o dist/bundle.js

# With transforms (Babel)
browserify src/main.js \
  -t [ babelify --presets @babel/preset-env ] \
  -o dist/bundle.js

# Watch mode
watchify src/main.js -o dist/bundle.js -v
```

### Using NPM Packages

```javascript
// src/main.js
const _ = require('lodash')
const $ = require('jquery')

const result = _.map([1, 2, 3], x => x * 2)
console.log(result)  // [2, 4, 6]
```

### Gulp Integration

```javascript
// gulpfile.js
const gulp = require('gulp')
const browserify = require('browserify')
const babelify = require('babelify')
const vinyl = require('vinyl-source-stream')
const buffer = require('vinyl-buffer')

gulp.task('js', () => {
  return browserify('src/main.js')
    .transform(babelify, { presets: ['@babel/preset-env'] })
    .bundle()
    .pipe(vinyl('bundle.js'))
    .pipe(buffer())
    .pipe(gulp.dest('dist'))
})

gulp.task('default', () => {
  gulp.watch('src/**/*.js', gulp.series('js'))
})
```

## Tree Shaking (Rollup / Webpack)

```javascript
// Only import what you use (ES modules)
import { debounce, throttle } from 'lodash-es'
// Webpack/Rollup tree-shakes unused exports

// Tree-shakeable CSS
import styles from './button.css'
// Webpack extracts CSS and tree-shakes unused rules
```

## Vite (Modern Build Tool)

```bash
npm create vite@latest myapp -- --template react
cd myapp
npm install
npm run dev
```

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  css: {
    preprocessorOptions: {
      scss: { additionalData: `@import "src/styles/vars";` }
    }
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        }
      }
    }
  }
})
```

## Comparison

| Tool | Type | Use Case |
|------|------|---------|
| **Sass** | CSS preprocessor | Compile .scss to CSS |
| **Less** | CSS preprocessor | Compile .less to CSS |
| **PostCSS** | CSS transformer | Autoprefixer, minify, future CSS |
| **Browserify** | Module bundler | Bundle CommonJS for browser |
| **Vite** | Dev server + bundler | Modern frontend dev |
| **Webpack** | Module bundler | Complex apps, code splitting |
| **Rollup** | Module bundler | Library packaging (tree-shaking) |

## Resources

- [awesome-sass](https://github.com/Famolus/awesome-sass)
- [awesome-postcss](https://github.com/jdrgomes/awesome-postcss)