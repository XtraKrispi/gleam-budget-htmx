/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,gleam}"],
  theme: {
    extend: {},
  },
  plugins: [require("@tailwindcss/typography"), require('daisyui')],
}

