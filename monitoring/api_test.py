from abc import ABC, abstractmethod
import time

import requests
from faker import Faker


class APIHandler(ABC):
    def __init__(self, model: str, host: str = "http://localhost:8000"):
        self.root_url = "/forum/topic"
        self.model = model
        self.host = host
        self.access, self.refresh = self._login()

    def _get_url(self, detail=False, pk: int = None) -> str:
        if detail:
            return f"{self.host}{self.root_url}/{pk}/"
        return f"{self.host}{self.root_url}/"

    @abstractmethod
    def _generate_data(self, fk: int = None) -> dict:
        """
        generate data for POST, PUT
        """
        ...

    def _get_pk(self, model: str = None) -> int:
        res = self.list(model)

        return res.json()[0].get("id")

    def _login(self) -> tuple:
        url = f"{self.host}/api/token/"
        data = {
            "username": "lion",
            "password": "lion!Q@W#E$R",
        }
        res = requests.post(url, data=data)
        print(type(res))
        print(res)
        res_data = res.json()
        return res_data.get("access"), res_data.get("refresh")

    def _api_call(self, method: str, url: str, data: dict = None):
        request = {
            "url": url,
            "data": data,
            "headers": {"Authorization": f"Bearer {self.access}"},
        }
        res = getattr(requests, method)(**request)
        if res.status_code >= 400:
            print(res.json())
        return res

    @abstractmethod
    def create(self):
        ...

    @abstractmethod
    def list(self, model: str = None):
        ...

    @abstractmethod
    def update(self):
        ...

    def destroy(self):
        pk = self._get_pk()
        self._api_call("delete", self._get_url(detail=True, pk=pk))

    def detail(self):
        pk = self._get_pk()
        self._api_call("get", self._get_url(detail=True, pk=pk))


class TopicAPIHandler(APIHandler):
    def __init__(self, host: str = "http://localhost:8000"):
        super().__init__("topic", host)
        self.root_url = "/forum/topic"

    def _generate_data(self, fk: int = None) -> dict:
        fake = Faker()
        data = {
            "name": fake.text(max_nb_chars=10),
            "is_private": False,
        }
        return data

    def create(self):
        self._api_call(method="post", url=self._get_url(), data=self._generate_data())

    def list(self, model: str = None):
        res = self._api_call("get", self._get_url())
        return res

    def update(self):
        pk = self._get_pk()
        self._api_call(
            "put", self._get_url(detail=True, pk=pk), data=self._generate_data()
        )
        return


class PostAPIHandler(APIHandler):
    def __init__(self, host: str = "http://localhost:8000"):
        super().__init__("post", host)
        self.root_url = "/forum/post"

    def _generate_data(self, fk: int = None) -> dict:
        fake = Faker()
        data = {
            "topic": fk,
            "title": fake.text(max_nb_chars=20),
            "content": fake.text(max_nb_chars=100),
        }
        return data

    def _get_pk(self, model: str = None) -> int:
        res = self._api_call("get", f"{self.host}/forum/topic/")
        return res.json()[0].get("id")

    def create(self):
        fk = self._get_pk("topic")
        self._api_call(method="post", url=self._get_url(), data=self._generate_data(fk))
        return

    def list(self, model: str = None):
        res = self._api_call(
            "get", f"{self.host}/forum/topic/{self._get_pk(model='topic')}/posts"
        )

    def update(self):
        pk = self._get_pk()
        fk = self._get_pk("topic")
        self._api_call(
            "put", self._get_url(detail=True, pk=pk), data=self._generate_data(fk)
        )


if __name__ == "__main__":
    topic_handler = TopicAPIHandler()
    post_handler = PostAPIHandler()

    i = 0

    while True:
        topic_handler.create()
        post_handler.create()
        topic_handler.update()
        post_handler.detail()
        if i % 30 == 0:
            post_handler.destroy()
        i += 1
        time.sleep(1)
