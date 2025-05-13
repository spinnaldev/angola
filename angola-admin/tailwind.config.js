/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          light: '#5B8DEF',
          DEFAULT: '#3A70D9',
          dark: '#2855A8',
        },
        secondary: {
          light: '#FFA263',
          DEFAULT: '#FF8A30',
          dark: '#E67012',
        },
        accent: {
          light: '#55C2C3',
          DEFAULT: '#3AABAC',
          dark: '#2A8889',
        },
        background: '#F5F7FA',
        surface: '#FFFFFF',
        text: {
          primary: '#1A2236',
          secondary: '#4F5B76',
          disabled: '#9EA5B8',
        },
        success: '#4CAF50',
        warning: '#FFC107',
        error: '#E53935',
        info: '#2196F3',
      },
      fontFamily: {
        sans: ['Poppins', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
    },
  },
  plugins: [],
}