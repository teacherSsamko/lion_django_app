#!/bin/bash

USERNAME="lion"
PASSWORD=

# getopts 로 전달 받아서 작업 수행
while getops "u:p:" opt; do
    case $opt in
        u) 
            USERNAME=$OPTARG
            ;;
        p) 
            PASSWORD=$OPTARG
            ;;
        *) 
            echo "Usage: $0 [-u username] [-p password]"
            exit 1
            ;;
    esac
done

if [ -z $PASSWORD ]; then
    echo "password is required"
    echo "Usage: $0 [-u username] [-p password]"
    exit 1
fi

# user 추가
echo "Add user"
useradd -s /bin/bash -d /home/$USERNAME -m $USERNAME

# password 변경
echo "Set password"
echo "$USERNAME:$PASSWORD" | chpasswd

# sudoer에 추가
echo "Add sudoer"
echo "$USERNAME ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME

