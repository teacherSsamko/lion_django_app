import requests
from faker import Faker

r = requests.get("http://localhost:8000/health/")
print(r.json())


# model의 각 API(API 문서에 있는)를 호출하는 함수 (topic, post)
class APIHandler:
    urls = {
        "topic": "/forum/topic/",
        "post": "/forum/post/",
    }

    def __init__(self, model: str, host: str = "localhost"):
        self.model = model
        self.host = host

    def _get_url(self, detail=False, pk: int = None) -> str:
        root_url = f"{self.host}{self.urls.get(self.model)}"
        if detail:
            return f"{root_url}{pk}"
        return root_url

    def _generate_data(self, fk: int) -> dict:
        fake = Faker()
        if self.model == "post":
            data = {
                "topic": fk,
                "title": fake.text(max_nb_chars=20),
                "content": fake.text(max_nb_chars=100),
            }
        elif self.model == "topic":
            data = {
                "name": fake.text(max_nb_chars=10),
                "is_private": False,
                "owner": fk,
            }
        else:
            raise Exception

        return data

    def _get_pk(self, model: str = None) -> int:
        return 0

    def create(self):
        fk = self._get_pk()
        requests.post(self._get_url(), data=self._generate_data(fk))

    def list(self):
        if self.model == "topic":
            res = requests.get(self._get_url())
        elif self.model == "post":
            res = requests.get("")
        else:
            raise Exception

        return res

    def update(self):
        pk = self._get_pk()
        fk = self._get_pk()
        requests.put(self._get_url(detail=True, pk=pk), data=self._generate_data(fk))

    def destroy(self):
        pk = self._get_pk()
        requests.delete(self._get_url(detail=True, pk=pk))

    def detail(self):
        pk = self._get_pk()
        requests.get(self._get_url(detail=True, pk=pk))


if __name__ == "__main__":
    topic_handler = APIHandler("topic")
    post_handler = APIHandler("post")

    topic_handler.create()
    post_handler.destroy()
