-- First, ensure we have the http extension enabled
CREATE EXTENSION IF NOT EXISTS "http";

-- ======= TRIGGER FOR NEW BOOKINGS =======

-- 1. Create a function that will be called when a new booking is inserted
CREATE OR REPLACE FUNCTION public.handle_new_booking()
RETURNS TRIGGER AS $$
BEGIN
  -- Make an HTTP POST request to your Edge Function
  PERFORM
    http_post(
      'https://sokfvqtgpbeybjifaywh.supabase.co/functions/v1/booking-notification',  
      jsonb_build_object(
        'record', json_build_object(
          'id', NEW.id,
          'title', NEW.title,
          'description', NEW.description,
          'room_id', NEW.room_id,
          'room_name', NEW.room_name,
          'room_capacity', NEW.room_capacity,
          'start_time', NEW.start_time,
          'end_time', NEW.end_time,
          'status', NEW.status,
          'created_by_email', NEW.created_by_email,
          'created_by_name', NEW.created_by_name,
          'created_at', NEW.created_at
        ),
        'type', 'new_booking'
      ),

      '{"Content-Type": "application/json"}',
      60  -- Timeout in seconds
    );
  RETURN NEW;  -- Return the new row, which continues the insert operation
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;  -- SECURITY DEFINER means it runs with the privileges of the function creator

-- 2. Create a trigger that calls this function after each new booking insert
CREATE OR REPLACE TRIGGER on_new_booking_inserted
  AFTER INSERT ON bookings  
  FOR EACH ROW              
  EXECUTE FUNCTION public.handle_new_booking();


-- ======= TRIGGER FOR BOOKING CONFIRMATIONS =======

-- 1. Create a function for when bookings are approved
CREATE OR REPLACE FUNCTION public.handle_booking_approval()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger when the booking gets approved (approved_at changes from NULL to a timestamp)
  IF (OLD.approved_at IS NULL AND NEW.approved_at IS NOT NULL) THEN
    PERFORM
      http_post(
        'https://sokfvqtgpbeybjifaywh.supabase.co/functions/v1/booking-notification',
        jsonb_build_object(
          'record', json_build_object(
            'id', NEW.id,
            'title', NEW.title,
            'description', NEW.description,
            'room_id', NEW.room_id,
            'room_name', NEW.room_name,
            'room_capacity', NEW.room_capacity,
            'start_time', NEW.start_time,
            'end_time', NEW.end_time,
            'status', NEW.status,
            'created_by_email', NEW.created_by_email,
            'created_by_name', NEW.created_by_name,
            'created_at', NEW.created_at,
            'approved_by_email', NEW.approved_by_email,
            'approved_at', NEW.approved_at
          ),
          'type', 'confirmed_booking'
        ),
        '{"Content-Type": "application/json"}',
        60
      );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create a trigger that calls this function after booking updates
CREATE OR REPLACE TRIGGER on_booking_approved
  AFTER UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_booking_approval();

