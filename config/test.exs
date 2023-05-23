import Config

config :postgrex_agtype,
  postage: [
    hostname: "localhost",
    port: 5432,
    username: "postgres",
    password: "postgres",
    database: "postgrex_agtype_test",
    types: PostgrexAgtype.PostgresTypes
  ]
