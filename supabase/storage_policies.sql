drop policy if exists "firebase_users_upload_to_own_storage_folder"
  on storage.objects;

create policy "firebase_users_upload_to_own_storage_folder"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'app-files'
    and (
      (
        (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
        and (storage.foldername(name))[2] in ('lostFound', 'reports', 'resources')
      )
      or (storage.foldername(name))[1] = 'qa'
    )
  );
