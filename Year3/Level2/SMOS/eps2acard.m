function Acard=eps2acard(epsr)
B_card=0.8;
eps1=real(epsr); eps2=imag(epsr);
m_card=sqrt((eps1-B_card).*(eps1-B_card)+eps2.*eps2);
Acard=m_card.*m_card./(m_card+eps1-B_card);