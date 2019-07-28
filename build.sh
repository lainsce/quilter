clear
#meson build --prefix=/usr #GOBJECT_DEBUG=instance-count
clear
cd build
ninja
G_MESSAGES_DEBUG=all ./com.github.lainsce.quilter
