// Standard API response envelope: { success, data, error }
// Usage: res.json(success({ ... }))  /  res.status(400).json(error('message'))

function success(data) {
  return {
    success: true,
    data,
    error: null
  };
}

function error(message) {
  return {
    success: false,
    data: null,
    error: message
  };
}

module.exports = { success, error };
