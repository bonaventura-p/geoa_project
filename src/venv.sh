python -m venv virtualenv
source ./virtualenv/bin/activate
pip install -r src/requirements.txt

pip uninstall twint
pip install --upgrade git+https://github.com/himanshudabas/twint.git@origin/twint-fixes#egg=twint

#deactivate


#git+https://github.com/yunusemrecatalcam/twint.git@twitter_legacy2
#git+https://github.com/twintproject/twint.git@origin/master#egg=twint