#!/bin/sh

NUM_CPU=${1:-1}

echo "HAL9000: Installing fake 'nproc' in /usr/local/bin to avoid system hangs..."
if [ ! -f /usr/local/bin/nproc ]; then
	sudo sh -c 'echo "#!/bin/sh"         >  /usr/local/bin/nproc'
	sudo sh -c 'echo "echo '${NUM_CPU}'" >> /usr/local/bin/nproc'
	sudo chmod 755 /usr/local/bin/nproc
fi

