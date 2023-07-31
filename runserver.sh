APP_NAME=lion_app

# git pull
echo "git pull"
git pull
# 가상환경 적용 (source)
echo "start to activate venv"
source venv/bin/activate
# runserver
echo "runserver"
python $APP_NAME/manage.py runserver 0.0.0.0:8000
