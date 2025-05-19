import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts";

const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || ''
const emailHost = Deno.env.get('EMAIL_HOST') || ''
const emailPort = parseInt(Deno.env.get('EMAIL_PORT') || '587')
const emailUser = Deno.env.get('EMAIL_USER') || ''
const emailPass = Deno.env.get('EMAIL_PASS') || ''
const officeManagerEmail = Deno.env.get('OFFICE_MANAGER_EMAIL') || ''

serve(async (req) => {
  try {
    const { record, type } = await req.json()
    
    // Connect to Supabase
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    // Configure email client
    const client = new SmtpClient()
    await client.connectTLS({
      hostname: emailHost,
      port: emailPort,
      username: emailUser,
      password: emailPass,
    })
    
    let subject = ''
    let body = ''
    
    // Determine email content based on the event type
    if (type === 'new_booking') {
      // Get additional booking details if needed
      subject = 'New Booking Request'
      body = `A new booking request has been received.\n\n` +
             `Booking ID: ${record.id}\n` +
             `Date: ${record.date}\n` +
             `Customer: ${record.customer_name}\n` +
             `Additional Details: ${record.details || 'None'}`
    } else if (type === 'confirmed_booking') {
      subject = 'Booking Confirmed'
      body = `A booking has been confirmed.\n\n` +
             `Booking ID: ${record.id}\n` +
             `Date: ${record.date}\n` +
             `Customer: ${record.customer_name}\n` +
             `Additional Details: ${record.details || 'None'}`
    }
    
    // Send the email
    await client.send({
      from: emailUser,
      to: officeManagerEmail,
      subject: subject,
      content: body,
    })
    
    await client.close()
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
