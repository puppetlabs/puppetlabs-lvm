test_name 'Add extra hard drive for LVM testing'


# Get the auth_token from ENV
auth_tok = ENV['AUTH_TOKEN']

# On the PE agent where LVM running
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    step 'adding an extra disk'
    on(agent, "curl -X POST -H X-AUTH-TOKEN:#{auth_tok} --url vcloud/api/v1/vm/#{agent[:vmhostname]}/disk/1")
    sleep(120)

    step 'rescan the SCSI bus on the host to make the newly added hdd recognized'
    on(agent, "echo \"- - -\" >/sys/class/scsi_host/host0/scan")


    #on(agent, "curl -X POST -H X-AUTH-TOKEN:c00nem2oao477lyc1olnr2k6zgquchxl --url vcloud/api/v1/vm/#{agent[:vmhostname]}/disk/4")
    on(agent, "curl -X POST -H X-AUTH-TOKEN:#{auth_tok} --url vcloud/api/v1/vm/#{agent[:vmhostname]}/disk/1")
    sleep(120)

    step 'rescan the SCSI bus on the host to make the newly added hdd recognized'
    on(agent, "echo \"- - -\" >/sys/class/scsi_host/host0/scan")

    step 'Verify the newly add hdd recognized:'
    on(agent, "fdisk -l") do |result|
      assert_match(/\/dev\/sdc/, result.stdout, "Unexpected errors is detected")
      assert_match(/\/dev\/sdd/, result.stdout, "Unexpected errors is detected")
    end
  end
end