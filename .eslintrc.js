module.exports = {
  env: {
    browser: false,
    commonjs: true,
    es2021: true,
    node: true,
    jest: true
  },
  extends: [
    'airbnb-base',
    'plugin:jest/recommended'
  ],
  parserOptions: {
    ecmaVersion: 'latest'
  },
  plugins: ['jest'],
  rules: {
    'no-console': 'off',
    'consistent-return': 'off',
    'no-param-reassign': ['error', { props: false }],
    'no-plusplus': 'off',
    'prefer-destructuring': ['error', { object: true, array: false }],
    'max-len': ['warn', { code: 120, ignoreComments: true }],
    'arrow-body-style': 'off',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'comma-dangle': ['error', 'only-multiline']
  }
};