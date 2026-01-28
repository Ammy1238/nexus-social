module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testMatch: ['**/*.spec.ts'],
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  collectCoverageFrom: [
    '**/*.{ts,js}',
    '!**/node_modules/**',
    '!**/dist/**',
    '!**/coverage/**',
    '!**/config/**',
    '!**/testing/**',
    '!**/main.ts',
    '!**/*.module.ts',
    '!**/*.event.ts',
    '!**/*.dto{,s}.ts',
    '!**/*.interface{,s}.ts',
    '!**/*.constants.ts',
    '!**/*.schema.ts',
  ],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
  moduleNameMapper: {
    '^src/(.*)$': '<rootDir>/$1',
  },
};
