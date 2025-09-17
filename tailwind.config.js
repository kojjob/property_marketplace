/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'primary-blue': '#00aeff',
        'property-blue': '#0073e6',
        'property-dark': '#1a1a1a',
      },
      fontFamily: {
        'roboto': ['Roboto', 'sans-serif'],
        'lora': ['Lora', 'serif'],
      }
    },
  },
  plugins: [
    require('daisyui'),
  ],
  daisyui: {
    themes: [
      {
        propertyMarketplace: {
          "primary": "#00aeff",
          "primary-content": "#ffffff",
          "secondary": "#0073e6",
          "secondary-content": "#ffffff",
          "accent": "#37cdbe",
          "accent-content": "#163835",
          "neutral": "#3d4451",
          "neutral-content": "#ffffff",
          "base-100": "#ffffff",
          "base-200": "#f9fafb",
          "base-300": "#f3f4f6",
          "base-content": "#1f2937",
          "info": "#3abff8",
          "info-content": "#002b3d",
          "success": "#36d399",
          "success-content": "#003320",
          "warning": "#fbbd23",
          "warning-content": "#382800",
          "error": "#f87272",
          "error-content": "#470000",
        },
      },
      "light",
      "dark",
      "corporate"
    ],
    base: true,
    styled: true,
    utils: true,
    prefix: "",
    logs: true,
    themeRoot: ":root",
  },
}