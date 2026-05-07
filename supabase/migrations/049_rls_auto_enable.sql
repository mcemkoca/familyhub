-- Automatic RLS enable trigger for new tables
CREATE OR REPLACE FUNCTION rls_auto_enable()
RETURNS EVENT TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS')
  LOOP
    EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', cmd.object_identity);
  END LOOP;
END;
$$;

DROP EVENT TRIGGER IF EXISTS ensure_rls;
CREATE EVENT TRIGGER ensure_rls ON ddl_command_end
WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS')
EXECUTE FUNCTION rls_auto_enable();
