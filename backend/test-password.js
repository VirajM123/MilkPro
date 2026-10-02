const bcrypt = require("bcryptjs");

const enteredPassword = "123456";

const storedHash =
  "$2b$12$AIPn6XEiVehKsHV7ukIeV./Oj3s7RZRHfqI3zHFcRfRKBzsY68d.2";

async function test() {
  const result = await bcrypt.compare(
    enteredPassword,
    storedHash
  );

  console.log("Password Match:", result);
}

test();