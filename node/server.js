const fastify = require("fastify")({
  logger: true,
});

fastify.register(require("@fastify/mysql"), {
  promise: true,
  connectionString: `mysql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}/${process.env.DB_NAME}`,
});

fastify.get("/", async () => {
  return {hello: "world"};
});

fastify.get("/todo", async () => {
  const connection = await fastify.mysql.getConnection();
  const [rows] = await connection.query("SELECT * FROM todo");
  connection.release();
  return rows;
});

fastify.get("/todo/:id", async (request) => {
  const {id} = request.params;
  const connection = await fastify.mysql.getConnection();
  const [rows] = await connection.query("SELECT * FROM todo WHERE id = ?", [id]);
  connection.release();
  return rows;
});

// Add a new item
fastify.post("/todo", async (request) => {
  const {title, completed} = request.body;
  await fastify.mysql.query("INSERT INTO todo (title) VALUES (?, ?)", [title, completed]);
  return {status: "ok"};
});

// Update an item
fastify.put("/todo/:id", async (request) => {
  const {id} = request.params;
  const {title} = request.body;
  await fastify.mysql.query("UPDATE todo SET title = ? WHERE id = ?", [title, completed, id]);
  return {status: "ok"};
});

// Delete an item
fastify.delete("/todo/:id", async (request) => {
  const {id} = request.params;
  await fastify.mysql.query("DELETE FROM todo WHERE id = ?", [id]);
  return {status: "ok"};
});

fastify.listen({host: process.env.ADDRESS || "0.0.0.0", port: parseInt(process.env.PORT || 3000, 10)}, function (err) {
  if (err) {
    fastify.log.error(err);
    process.exit(1);
  }
});
