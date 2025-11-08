/**
 * Firebase Cloud Functions for Taxed GmbH
 *
 * Email notifications using SendGrid
 *
 * Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

admin.initializeApp();

// Initialize SendGrid
const SENDGRID_API_KEY = functions.config().sendgrid.key;
sgMail.setApiKey(SENDGRID_API_KEY);

const FROM_EMAIL = 'noreply@taxed.ch';
const FROM_NAME = 'Taxed GmbH';

// MARK: - Workspace Invitations

/**
 * Send workspace invitation email
 * Triggered when a new workspace invitation is created
 */
exports.sendWorkspaceInvitation = functions
    .region('europe-west6')
    .firestore
    .document('workspaceInvitations/{invitationId}')
    .onCreate(async (snap, context) => {
        const invitation = snap.data();

        console.log('Sending workspace invitation to:', invitation.invitedEmail);

        const msg = {
            to: invitation.invitedEmail,
            from: {
                email: FROM_EMAIL,
                name: FROM_NAME
            },
            subject: `Invitation to join workspace: ${invitation.workspaceName}`,
            text: `
You've been invited to join "${invitation.workspaceName}" workspace on Taxed.

Invited by: ${invitation.invitedByName}
Role: ${invitation.role}

Accept invitation in the Taxed app.

This invitation expires on ${new Date(invitation.expiresAt._seconds * 1000).toLocaleDateString()}.
            `,
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: #E31E24;
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 8px 8px 0 0;
        }
        .content {
            background: #f9f9f9;
            padding: 30px;
            border: 1px solid #ddd;
            border-top: none;
        }
        .button {
            display: inline-block;
            background: #E31E24;
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 6px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            color: #999;
            font-size: 12px;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Workspace Invitation</h1>
    </div>
    <div class="content">
        <h2>You've been invited!</h2>
        <p>
            <strong>${invitation.invitedByName}</strong> has invited you to join the
            <strong>${invitation.workspaceName}</strong> workspace on Taxed.
        </p>

        <p>Your role will be: <strong>${invitation.role}</strong></p>

        <p>
            <a href="taxed://invitation/${context.params.invitationId}" class="button">
                Accept Invitation
            </a>
        </p>

        <p style="font-size: 14px; color: #666;">
            This invitation expires on ${new Date(invitation.expiresAt._seconds * 1000).toLocaleDateString()}.
        </p>
    </div>
    <div class="footer">
        <p>Taxed GmbH | Aegertenstrasse 10, 2503 Biel/Bienne, Switzerland</p>
        <p>If you didn't expect this invitation, you can safely ignore this email.</p>
    </div>
</body>
</html>
            `
        };

        try {
            await sgMail.send(msg);
            console.log('Invitation email sent successfully to:', invitation.invitedEmail);

            // Update invitation with sent status
            await snap.ref.update({
                emailSent: true,
                emailSentAt: admin.firestore.FieldValue.serverTimestamp()
            });
        } catch (error) {
            console.error('Error sending invitation email:', error);
            throw new functions.https.HttpsError('internal', 'Failed to send invitation email');
        }
    });

// MARK: - Tax Deadline Reminders

/**
 * Send tax deadline reminders
 * Scheduled function that runs daily
 */
exports.sendTaxDeadlineReminders = functions
    .region('europe-west6')
    .pubsub
    .schedule('0 9 * * *')  // Run daily at 9 AM
    .timeZone('Europe/Zurich')
    .onRun(async (context) => {
        console.log('Running tax deadline reminder check...');

        const db = admin.firestore();
        const today = new Date();

        // Get all users
        const usersSnapshot = await db.collection('users').get();

        for (const userDoc of usersSnapshot.docs) {
            const user = userDoc.data();
            const canton = user.canton;

            if (!canton) continue;

            // Get tax deadline for canton
            const deadline = getCantonTaxDeadline(canton);

            if (!deadline) continue;

            // Check if deadline is in 30 days
            const daysUntilDeadline = Math.floor((deadline - today) / (1000 * 60 * 60 * 24));

            if (daysUntilDeadline === 30 || daysUntilDeadline === 14 || daysUntilDeadline === 7) {
                await sendDeadlineReminderEmail(user, canton, deadline, daysUntilDeadline);
            }
        }

        console.log('Tax deadline reminders sent');
    });

function getCantonTaxDeadline(canton) {
    const currentYear = new Date().getFullYear();

    // Most cantons: March 31
    const deadlines = {
        'ZH': new Date(currentYear, 2, 31),  // March 31
        'BE': new Date(currentYear, 2, 31),
        'GE': new Date(currentYear, 3, 30),  // April 30
        'VD': new Date(currentYear, 2, 31),
        'BS': new Date(currentYear, 2, 31),
        'ZG': new Date(currentYear, 2, 31)
    };

    return deadlines[canton] || new Date(currentYear, 2, 31);
}

async function sendDeadlineReminderEmail(user, canton, deadline, daysRemaining) {
    const msg = {
        to: user.email,
        from: {
            email: FROM_EMAIL,
            name: FROM_NAME
        },
        subject: `Tax deadline reminder: ${daysRemaining} days remaining`,
        html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: #E31E24;
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 8px 8px 0 0;
        }
        .content {
            background: #f9f9f9;
            padding: 30px;
            border: 1px solid #ddd;
        }
        .deadline-box {
            background: #fff;
            border-left: 4px solid #E31E24;
            padding: 20px;
            margin: 20px 0;
        }
        .button {
            display: inline-block;
            background: #E31E24;
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 6px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>⏰ Tax Deadline Reminder</h1>
    </div>
    <div class="content">
        <h2>Hello ${user.name},</h2>

        <div class="deadline-box">
            <h3 style="margin-top: 0;">Tax filing deadline: ${deadline.toLocaleDateString()}</h3>
            <p style="font-size: 24px; color: #E31E24; margin: 10px 0;">
                <strong>${daysRemaining} days remaining</strong>
            </p>
            <p>Canton: ${canton}</p>
        </div>

        <p>Make sure you have:</p>
        <ul>
            <li>✓ Uploaded all required documents</li>
            <li>✓ Reviewed your categorization</li>
            <li>✓ Checked all deductions</li>
            <li>✓ Generated cover sheets</li>
        </ul>

        <p>
            <a href="taxed://documents" class="button">
                Open Taxed App
            </a>
        </p>

        <p style="font-size: 14px; color: #666;">
            Need help? Contact our tax experts in the app.
        </p>
    </div>
</body>
</html>
        `
    };

    try {
        await sgMail.send(msg);
        console.log(`Deadline reminder sent to ${user.email}`);
    } catch (error) {
        console.error(`Error sending deadline reminder to ${user.email}:`, error);
    }
}

// MARK: - Document Processing Notifications

/**
 * Notify user when document processing is complete
 */
exports.notifyDocumentProcessed = functions
    .region('europe-west6')
    .firestore
    .document('documents/{documentId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        // Check if PDF generation just completed
        if (before.pdfGenerationStatus !== 'completed' &&
            after.pdfGenerationStatus === 'completed') {

            // Get user
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(after.customerId)
                .get();

            if (!userDoc.exists) return;

            const user = userDoc.data();

            const msg = {
                to: user.email,
                from: {
                    email: FROM_EMAIL,
                    name: FROM_NAME
                },
                subject: `Document processed: ${after.name}`,
                html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 20px;">
    <h2>✅ Document Processed</h2>
    <p>Your document <strong>${after.name}</strong> has been processed and is ready for review.</p>
    <p>Category: ${after.subcategory || 'Uncategorized'}</p>
    <p>
        <a href="taxed://document/${context.params.documentId}"
           style="display: inline-block; background: #E31E24; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px;">
            View Document
        </a>
    </p>
</body>
</html>
                `
            };

            try {
                await sgMail.send(msg);
                console.log(`Document processed notification sent to ${user.email}`);
            } catch (error) {
                console.error('Error sending document notification:', error);
            }
        }
    });

// MARK: - Expert Chat Notifications

/**
 * Notify user of new expert message
 */
exports.notifyNewExpertMessage = functions
    .region('europe-west6')
    .firestore
    .document('messages/{messageId}')
    .onCreate(async (snap, context) => {
        const message = snap.data();

        // Only notify if message is from expert to customer
        if (message.senderRole !== 'expert') return;

        // Get conversation
        const conversationDoc = await admin.firestore()
            .collection('chats')
            .doc(message.conversationId)
            .get();

        if (!conversationDoc.exists) return;

        const conversation = conversationDoc.data();

        // Get customer
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(conversation.customerId)
            .get();

        if (!userDoc.exists) return;

        const user = userDoc.data();

        const msg = {
            to: user.email,
            from: {
                email: FROM_EMAIL,
                name: FROM_NAME
            },
            subject: `New message from ${message.senderName}`,
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 20px;">
    <h2>💬 New Message from Your Tax Expert</h2>
    <p><strong>${message.senderName}</strong> sent you a message:</p>
    <div style="background: #f5f5f5; padding: 15px; border-left: 4px solid #E31E24; margin: 20px 0;">
        ${message.content}
    </div>
    <p>
        <a href="taxed://chat/${message.conversationId}"
           style="display: inline-block; background: #E31E24; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px;">
            Reply in App
        </a>
    </p>
</body>
</html>
            `
        };

        try {
            await sgMail.send(msg);
            console.log(`Expert message notification sent to ${user.email}`);
        } catch (error) {
            console.error('Error sending expert message notification:', error);
        }
    });

// MARK: - Welcome Email

/**
 * Send welcome email to new users
 */
exports.sendWelcomeEmail = functions
    .region('europe-west6')
    .firestore
    .document('users/{userId}')
    .onCreate(async (snap, context) => {
        const user = snap.data();

        const msg = {
            to: user.email,
            from: {
                email: FROM_EMAIL,
                name: FROM_NAME
            },
            subject: 'Welcome to Taxed - Your Swiss Tax Assistant',
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            padding: 20px;
            max-width: 600px;
            margin: 0 auto;
        }
        .header {
            background: #E31E24;
            color: white;
            padding: 40px;
            text-align: center;
            border-radius: 8px 8px 0 0;
        }
        .content {
            background: #f9f9f9;
            padding: 30px;
            border: 1px solid #ddd;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🇨🇭 Welcome to Taxed!</h1>
    </div>
    <div class="content">
        <h2>Hello ${user.name},</h2>

        <p>Welcome to Taxed - your intelligent Swiss tax filing assistant!</p>

        <h3>Get started in 3 easy steps:</h3>
        <ol>
            <li>📸 Upload your tax documents (camera or photo library)</li>
            <li>🤖 Let AI categorize them automatically</li>
            <li>✅ Review and generate tax-office compliant PDFs</li>
        </ol>

        <h3>Key features at your fingertips:</h3>
        <ul>
            <li>AI-powered document categorization</li>
            <li>Support for all 26 Swiss cantons</li>
            <li>Multi-language support (DE, FR, IT, EN)</li>
            <li>Expert tax consultation via chat</li>
            <li>Automatic tax calculations</li>
        </ul>

        <p>Questions? Our tax experts are ready to help!</p>

        <p style="margin-top: 40px; font-size: 14px; color: #666;">
            Best regards,<br>
            The Taxed Team
        </p>
    </div>
</body>
</html>
            `
        };

        try {
            await sgMrid.send(msg);
            console.log(`Welcome email sent to ${user.email}`);
        } catch (error) {
            console.error('Error sending welcome email:', error);
        }
    });
