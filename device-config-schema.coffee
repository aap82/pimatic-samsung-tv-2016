module.exports =
  SamsungTV_2016:
    title: "SamsungTV 2016 Models (and later) Switch Actuator config"
    type: "object"
    properties:
      ip_address:
        description:  "ip address for the samsung tv"
        type: "string"
        required: yes
      mac_address:
        description: "The mac address of the samsung tv. This can be auto-populated"
        type: "string"
      update_interval:
        description: "Interval in seconds to check and update TV state"
        type: "number"
        default: 15