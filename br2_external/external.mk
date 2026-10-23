include $(sort $(wildcard $(BR2_EXTERNAL_X6100_PATH)/package/*/*.mk))

export HOST_CXXFLAGS += -Wno-return-type -Wno-error=return-type -Wno-error -Wno-template-body
export HOST_CFLAGS += -std=gnu17

HOST_GDB_CONF_ENV += \
	CFLAGS="$(HOST_CFLAGS) -DNCURSES_BOOL=bool" \
	CXXFLAGS="$(HOST_CXXFLAGS) -std=gnu++17 -DNCURSES_BOOL=bool -fpermissive -Wno-error -w"

JPEG_TURBO_CONF_OPTS += -DCMAKE_POLICY_VERSION_MINIMUM=3.5
LIBUBOOTENV_CONF_OPTS += -DCMAKE_POLICY_VERSION_MINIMUM=3.5
NE10_CONF_OPTS += -DCMAKE_POLICY_VERSION_MINIMUM=3.5
