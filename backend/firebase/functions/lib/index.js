

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
exports.callClaudeAI = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  return { analysis: "Test response from N‚oSant‚" };
});
console.log("? N‚oSant‚ Functions loaded");
