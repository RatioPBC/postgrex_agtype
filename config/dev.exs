import Config

config :postgrex_agtype,
  postage: [
    hostname: "localhost",
    port: 5432,
    username: "postgres",
    password: "postgres",
    database: "postage",
    types: PostgrexAgtype.PostgresTypes
  ]
